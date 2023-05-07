package mytaxi.partola.models;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * @author Ivan Partola
 * @date 04.05.2023
 */

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Client extends CustomUser {
    @NotBlank(message = "Phone number is required")
    @Size(max = 13, message = "Invalid phone number, keep format +380-xxx-xxx-xxxx")
    private String phoneNumber;
    private int rating;
    private float bonusAmount;
}