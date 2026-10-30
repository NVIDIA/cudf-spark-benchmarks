WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
), TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        cu.c_name AS customer_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        RankedOrders o
    JOIN 
        customer cu ON o.o_orderkey = cu.c_custkey
    JOIN 
        nation n ON cu.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.order_rank <= 10
    GROUP BY 
        r.r_name, n.n_name, cu.c_name
), AverageSpend AS (
    SELECT 
        region_name, 
        nation_name, 
        AVG(total_spent) AS avg_spent
    FROM 
        TopCustomers
    GROUP BY 
        region_name, nation_name
)
SELECT 
    region_name, 
    nation_name, 
    avg_spent
FROM 
    AverageSpend
ORDER BY 
    region_name, nation_name;