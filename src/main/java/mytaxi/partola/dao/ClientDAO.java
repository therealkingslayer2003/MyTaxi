package mytaxi.partola.dao;

import mytaxi.partola.models.Client;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * @author Ivan Partola
 * @date 04.05.2023
 */
@Component
public class ClientDAO {
    private final JdbcTemplate jdbcTemplate;
    private final UserDAO userDAO;
    @Autowired
    public ClientDAO(JdbcTemplate jdbcTemplate, UserDAO userDAO) {
        this.jdbcTemplate = jdbcTemplate;
        this.userDAO = userDAO;
    }

    @Transactional
    public void createClient(Client client) {
        userDAO.createUser(client);

        int userId = jdbcTemplate.queryForObject("SELECT currval('user_id_seq')", Integer.class);

        jdbcTemplate.update(
                "INSERT INTO \"Client\" (client_id, phone_number) VALUES (?, ?)",
                userId,
                client.getPhoneNumber());
    }

    public void setHasActiveOrderStatus(Client client, boolean status) {
        jdbcTemplate.update(
                "update \"Client\" set has_active_order = ? where client_id = ?",
                status,
                client.getClientId());
    }

    public Optional<Client> findClientById(long id) {
        return jdbcTemplate.query("select * from \"User\" u inner join \"Client\" c on u.user_id = c.client_id where c.client_id=?",
                        new Object[]{id},
                        new BeanPropertyRowMapper<>(Client.class))
                .stream().findAny();
    }

    public Optional<Client> findClientByPhoneNumber(String phoneNumber) {
        return jdbcTemplate.query("select * from \"User\" u inner join \"Client\" c on u.user_id = c.client_id where c.phone_number=?",
                        new Object[]{phoneNumber},
                        new BeanPropertyRowMapper<>(Client.class))
                .stream().findAny();
    }


    @Transactional
    public void setBonusesByClientId(long clientId, float bonusesAmount) {
        jdbcTemplate.update(
                "update \"Client\" set bonus_amount = ? where client_id = ?;",
                bonusesAmount,
                clientId);
    }

    public void saveClient(Client client) {
        jdbcTemplate.update("INSERT INTO \"Client\" (client_id, phone_number," +
                        " client_rating, has_active_order, bonus_amount) VALUES (?, ?, ?, ?, ?) " +
                        "ON CONFLICT (client_id) DO UPDATE SET phone_number = excluded.phone_number, " +
                        "client_rating = excluded.client_rating, has_active_order = excluded.has_active_order, " +
                        "bonus_amount = excluded.bonus_amount",
                client.getClientId(),
                client.getPhoneNumber(),
                client.getClientRating(),
                client.isHasActiveOrder(),
                client.getBonusAmount());
    }

    public List<Client> getAllClients() {
        return jdbcTemplate.query("select * from \"Client\" ",
                new BeanPropertyRowMapper<>(Client.class));
    }
}
