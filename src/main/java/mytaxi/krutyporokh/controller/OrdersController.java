package mytaxi.krutyporokh.controller;

import mytaxi.krutyporokh.dao.OrderDAO;
import mytaxi.krutyporokh.models.Order;
import mytaxi.krutyporokh.services.OrderService;
import mytaxi.krutyporokh.validation.groups.OrderForAnotherPerson;
import mytaxi.krutyporokh.validation.groups.OrderForSelf;
import mytaxi.partola.dao.CarDAO;
import mytaxi.partola.dao.ClientDAO;
import mytaxi.partola.dao.DriverDAO;
import mytaxi.partola.models.Client;
import mytaxi.partola.models.CustomUser;
import mytaxi.partola.models.Driver;
import mytaxi.partola.services.ClientService;
import mytaxi.partola.services.CustomUserService;
import mytaxi.partola.services.DriverService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import javax.validation.ConstraintViolation;
import javax.validation.Valid;
import javax.validation.Validator;
import java.util.Set;

@Controller
public class OrdersController {
    private final OrderDAO orderDAO;
    private final ClientDAO clientDAO;
    private final DriverDAO driverDAO;
    private final CarDAO carDAO;
    private final Validator validator;
    private final ClientService clientService;
    private final CustomUserService customUserService;
    private final OrderService orderService;
    private final DriverService driverService;


    @Value("${googleMapsAPIKey}")
    private String googleMapsAPIKey;

    @Autowired
    public OrdersController(OrderDAO orderDAO, ClientDAO clientDAO, DriverDAO driverDAO, CarDAO carDAO, Validator validator, ClientService clientService, CustomUserService customUserService, OrderService orderService, DriverService driverService) {
        this.orderDAO = orderDAO;
        this.clientDAO = clientDAO;
        this.driverDAO = driverDAO;
        this.carDAO = carDAO;
        this.validator = validator;
        this.clientService = clientService;
        this.customUserService = customUserService;
        this.orderService = orderService;
        this.driverService = driverService;
    }

    @GetMapping("order")
    public String order (@ModelAttribute("order") Order order,
                         Model model) {
        model.addAttribute("googleMapsAPIKey", googleMapsAPIKey);
        // getUsername() method returns email in our case

        CustomUser currentUser = customUserService.getCurrentUserFromSession().get();
        model.addAttribute("user", currentUser);
        Client client = clientDAO.findClientById(currentUser.getUserId()).get();
        model.addAttribute("client", client);
        return "client/order";
    }

    @PostMapping("/createNewOrder")
    public String  createNewOrder(@RequestParam(name = "order-for-another-person", required = false) boolean orderForAnotherPerson,
                                  @ModelAttribute("order") @Valid Order order,
                                  BindingResult bindingResult,
                                  Model model
                               ){

        // Validate with the selected group
        Set<ConstraintViolation<Order>> violations;
        if (orderForAnotherPerson) {
            violations = validator.validate(order, OrderForAnotherPerson.class);
        } else {
            violations = validator.validate(order, OrderForSelf.class);
        }

        // Processing validation results
        if (!violations.isEmpty()) {
            for (ConstraintViolation<Order> violation : violations) {
                bindingResult.rejectValue(violation.getPropertyPath().toString(), null, violation.getMessage());
            }
        }

        CustomUser currentUser = customUserService.getCurrentUserFromSession().get();
        Client client = clientDAO.findClientById(currentUser.getUserId()).get();

        // Check if client already has active orders
        if (client.isHasActiveOrder()) {
            bindingResult.rejectValue("orderStatus", null, "You already have an active order.");
        }


        //Processing validation errors
        if(bindingResult.hasErrors()){
            //Re-adding Google Maps API key to avoid problems with map crash
            model.addAttribute("googleMapsAPIKey", googleMapsAPIKey);

            model.addAttribute("user", currentUser);
            model.addAttribute("client", client);
            model.addAttribute("bonusesAmount", client.getBonusAmount());
            model.addAttribute("error", bindingResult.getAllErrors());
            return "client/order";
        }
        // If user pays with bonuses, we remove them from their account
        clientService.subtractBonuses(client, order);
        orderDAO.createNewOrder(order, client);
        clientService.addBonusesByUserAndOrderPrice(currentUser, order.getPrice());
        clientDAO.setHasActiveOrderStatus(client, true);

        return "redirect:/my-orders";
    }

    @GetMapping("/order/{id}")
    public String activeOrder(@PathVariable long id,
                              Model model) {
        CustomUser currentUser = customUserService.getCurrentUserFromSession().get();
        Order currentOrder = orderDAO.findOrderById(id).get();

        // If this order is not order of current user, so we don't show it
        if (currentOrder.getClientId() != currentUser.getUserId()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Unable to find resource.");
        }

        Driver driver = driverDAO.findDriverById(currentOrder.getDriverId()).get();

        model.addAttribute("user", currentUser);
        model.addAttribute("driver", driver);
        model.addAttribute("order", currentOrder);
        model.addAttribute("car", carDAO.getCarByDriver(driver).get());
        return "client/activeOrder";
    }

    @PostMapping("/rateTheTrip/{id}")
    public ResponseEntity<?> ratedTrip (@PathVariable long id,
                                        @RequestParam int rating) {
        orderService.rateTrip(id, rating);
        return ResponseEntity.ok().build();
    }
}
