WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopCustomerOrders AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        SUM(oo.o_totalprice) AS total_spent
    FROM 
        RankedOrders oo
    JOIN 
        customer c ON oo.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        oo.order_rank <= 5
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    region_name,
    nation_name,
    AVG(total_spent) AS avg_spent
FROM 
    TopCustomerOrders
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, nation_name;
