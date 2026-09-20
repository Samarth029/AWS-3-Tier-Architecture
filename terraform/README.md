\# Terraform - AWS 3-Tier WordPress Architecture



This directory contains the Terraform Infrastructure as Code (IaC) configuration for recreating the AWS 3-tier WordPress architecture used in this project.



> \*\*Note:\*\* The original AWS infrastructure was created manually through the AWS Management Console. The Terraform configuration in this directory provides a reproducible Infrastructure as Code version of the architecture.



\## Architecture



The Terraform configuration recreates the following architecture:



```text

Internet

&#x20;  |

&#x20;  v

Application Load Balancer

&#x20;  |

&#x20;  v

Target Group

&#x20;  |

&#x20;  v

Auto Scaling Group

&#x20;  |

&#x20;  +-------------------+

&#x20;  |                   |

&#x20;  v                   v

EC2 Instance 1     EC2 Instance 2

&#x20;  |                   |

&#x20;  +---------+---------+

&#x20;            |

&#x20;            v

&#x20;       Amazon RDS MySQL

