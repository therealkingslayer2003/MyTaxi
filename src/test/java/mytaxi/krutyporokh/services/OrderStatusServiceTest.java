package mytaxi.krutyporokh.services;

import mytaxi.krutyporokh.dao.OrderDAO;
import mytaxi.krutyporokh.models.Order;
import mytaxi.partola.models.Client;
import mytaxi.partola.services.ClientService;
import mytaxi.partola.services.CustomUserService;
import mytaxi.partola.services.DriverService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.mockito.Mockito;
import java.util.Collections;
import static org.mockito.Mockito.*;
/**
 * @author Ivan Partola
 * @date 28.05.2023
 */

class OrderStatusServiceTest {
    private OrderStatusService orderStatusService;
    private OrderDAO orderDAO;
    private CustomUserService customUserService;
    private OrderManagementService orderManagementService;
    private ClientService clientService;
    private DriverService driverService;

    @BeforeEach
    void setup() {
        orderManagementService = Mockito.mock(OrderManagementService.class);
        driverService = Mockito.mock(DriverService.class);
        customUserService = Mockito.mock(CustomUserService.class);
        clientService = Mockito.mock(ClientService.class);
        orderDAO = Mockito.mock(OrderDAO.class);
        orderStatusService = new OrderStatusService(orderDAO, customUserService, orderManagementService, clientService, driverService);
    }

    @Test
    void subtractBonusesIfOrderWasCancelled() {
        String hash = "hash";
        Order testOrder = new Order();
        testOrder.setPrice(150);
        testOrder.setPayWithBonuses(false);
        testOrder.setClientId(1L);

        Client testClient = new Client();
        testClient.setBonusAmount(20);

        when(orderManagementService.findOrderByHash(hash)).thenReturn(testOrder);
        when(clientService.findClientById(anyLong())).thenReturn(testClient);
        when(orderDAO.findFinishedOrdersByClientId(anyInt())).thenReturn(Collections.singletonList(new Order()));

        orderStatusService.subtractBonusesIfOrderWasCancelled(hash);

        verify(clientService, times(1)).subtractSomeBonuses(eq(testOrder.getClientId()), eq(testClient.getBonusAmount()), eq(1.5f));
    }
}