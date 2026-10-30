WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
TopCustomerOrders AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(ro.o_orderkey) AS order_count,
        SUM(ro.o_totalprice) AS total_spent
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rank <= 5
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    region_name,
    nation_name,
    order_count,
    total_spent,
    RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM 
    TopCustomerOrders
ORDER BY 
    region_name, nation_name;