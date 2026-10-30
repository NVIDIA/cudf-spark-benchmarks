WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        co.c_name AS customer_name,
        ro.o_orderkey,
        ro.o_totalprice
    FROM 
        RankedOrders ro
    JOIN 
        customer co ON ro.c_nationkey = co.c_nationkey
    JOIN 
        nation n ON co.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.price_rank <= 10
)
SELECT 
    tc.region_name,
    tc.nation_name,
    COUNT(tc.customer_name) AS top_customer_count,
    SUM(tc.o_totalprice) AS total_spent,
    AVG(tc.o_totalprice) AS avg_spent
FROM 
    TopCustomers tc
GROUP BY 
    tc.region_name,
    tc.nation_name
ORDER BY 
    total_spent DESC;
