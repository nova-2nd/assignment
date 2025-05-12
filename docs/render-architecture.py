from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import Fargate, ECS, EC2ElasticIpAddress, ElasticContainerServiceService, ElasticContainerServiceContainer
from diagrams.aws.network import ALB, RouteTable, IGW, VPC, NATGateway, PrivateSubnet, PublicSubnet

with Diagram("Assignment Architecture", show=False, filename="architecture_diagram"):
    mainrt = RouteTable("Main route table\n(nginx-demo-main-rt)")

    with Cluster("VPC"):
        vpc = VPC("VPC\n(nginx-demo)")
        nginx_demo_ig = IGW("Internet Gateway\n(nginx-demo-ig)")
        pubrt = RouteTable("Public subnet route table\n(nginx-demo-pub-rt)")
        nginx_demo_pub_az_a_eip = EC2ElasticIpAddress("EIP\n(nginx-demo-pub-az-a-eip)")
        nginx_demo_pub_az_b_eip = EC2ElasticIpAddress("EIP\n(nginx-demo-pub-az-b-eip)")
        nginx_demo_pub_az_c_eip = EC2ElasticIpAddress("EIP\n(nginx-demo-pub-az-c-eip)")
        alb_ingress = ALB("Listener: HTTP\nListener:HTTPS")
        with Cluster("Availability Zone A"):
            with Cluster("Pub Subnet 1"):
                lb_aza = ALB("ALB AZ A\n(nginx-demo-lb)")
                nginx_demo_pub_az_a = PublicSubnet("Subnet\nnginx-demo-pub-az-a")
                nginx_demo_priv_az_a_ng = NATGateway("NG\n(nginx-demo-priv-az-a-ng)")
            with Cluster("Priv Subnet 1"):
                PrivateSubnet("nginx-demo-priv-az-a") << RouteTable("nginx-demo-priv-az-a-rt")
                fg_node1 = Fargate("Fargate Node")
                cont1 = ElasticContainerServiceContainer("Container\nnginx-demos/hello")
        with Cluster("Availability Zone B"):
            with Cluster("Pub Subnet 2"):
                lb_azb = ALB("ALB AZ B\n(nginx-demo-lb)")
                nginx_demo_pub_az_b = PublicSubnet("Subnet\nnginx-demo-pub-az-b")
                nginx_demo_priv_az_b_ng = NATGateway("NG\n(nginx-demo-priv-az-b-ng)")
            with Cluster("Priv Subnet 2"):
                PrivateSubnet("nginx-demo-priv-az-b") << RouteTable("nginx-demo-priv-az-b-rt")
                fg_node2 = Fargate("Fargate Node")
                cont2 = ElasticContainerServiceContainer("Container\nnginx-demos/hello")
        with Cluster("Availability Zone C"):
            with Cluster("Pub Subnet 3"):
                lb_azc = ALB("nALB AZ C\n(nginx-demo-lb)")
                nginx_demo_pub_az_c = PublicSubnet("Subnet\nnginx-demo-pub-az-c")
                nginx_demo_priv_az_c_ng = NATGateway("NG\n(nginx-demo-priv-az-c-ng)")
            with Cluster("Priv Subnet 3"):
                PrivateSubnet("nginx-demo-priv-az-c") << RouteTable("nginx-demo-priv-az-c-rt")
                fg_node3 = Fargate("Fargate Node")
                cont3 = ElasticContainerServiceContainer("Container\nnginx-demos/hello")

    nginx_demo_ig << Edge(minlen="4") << nginx_demo_pub_az_a_eip << Edge(minlen="4") << nginx_demo_priv_az_a_ng << Edge(minlen="4") << fg_node1
    nginx_demo_ig << Edge(minlen="4") << nginx_demo_pub_az_b_eip << Edge(minlen="4") << nginx_demo_priv_az_b_ng << Edge(minlen="4") << fg_node2
    nginx_demo_ig << Edge(minlen="4") << nginx_demo_pub_az_c_eip << Edge(minlen="4") << nginx_demo_priv_az_c_ng << Edge(minlen="4") << fg_node3
    nginx_demo_ig >> alb_ingress >> Edge(minlen="4") >> [lb_aza, lb_azb, lb_azc]
    lb_aza >> Edge(label="HTTP") >> fg_node1
    lb_azb >> Edge(label="HTTP") >> fg_node2
    lb_azc >> Edge(label="HTTP") >> fg_node3
    mainrt >> vpc
    pubrt >> Edge(minlen="4") >> [nginx_demo_pub_az_a, nginx_demo_pub_az_b, nginx_demo_pub_az_c]
    ECS("ECS Control plane") >> ElasticContainerServiceService("ECS Service") >> Edge(minlen="2") >> [cont1, cont2, cont3]
    fg_node1 << cont1
    fg_node2 << cont2
    fg_node3 << cont3
