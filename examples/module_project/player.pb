use "rules";
use "items";

export class Player
{
  init(name)
  {
    this.name = name;
    this.health = rules.maxHealth;
    this.power = 18;
    this.armor = 4;
    this.experience = 0;
    this.inventory = [items.healthPotion(), items.healthPotion()];
  }

  isAlive()
  {
    return this.health > 0;
  }

  attack(target)
  {
    let amount = rules.damage(this.power, target.armor);
    target.health = target.health - amount;
    if (target.health < 0)
      target.health = 0;
    return amount;
  }

  heal()
  {
    if (len(this.inventory) == 0)
      return 0;

    let potion = this.inventory.pop();
    let oldHealth = this.health;
    this.health = this.health + potion["healing"];
    if (this.health > rules.maxHealth)
      this.health = rules.maxHealth;
    return this.health - oldHealth;
  }

  gainExperience(level)
  {
    this.experience = this.experience + rules.reward(level);
  }
}
