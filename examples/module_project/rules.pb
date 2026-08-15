export let maxHealth = 100;

export fun damage(power, armor)
{
  let amount = power - armor;
  if (amount < 1)
    return 1;
  return amount;
}

export fun reward(level)
{
  return level * 20;
}
