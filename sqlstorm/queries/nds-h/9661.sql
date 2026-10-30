WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        ro.c_name AS customer_name,
        ro.o_totalprice
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rn <= 5
)
SELECT 
    tc.region_name,
    tc.nation_name,
    COUNT(*) AS top_customers_count,
    SUM(tc.o_totalprice) AS total_spent,
    AVG(tc.o_totalprice) AS avg_spent
FROM 
    TopCustomers tc
GROUP BY 
    tc.region_name, 
    tc.nation_name
ORDER BY 
    total_spent DESC, 
    top_customers_count DESC;