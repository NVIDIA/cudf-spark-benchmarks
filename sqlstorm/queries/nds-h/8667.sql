
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        c.c_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_acctbal, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        roc.c_name AS customer_name,
        roc.total_revenue
    FROM 
        RankedOrders roc
    JOIN 
        customer c ON roc.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        roc.revenue_rank <= 10
)
SELECT 
    region_name,
    nation_name,
    customer_name,
    SUM(total_revenue) AS total_revenue
FROM 
    TopCustomers
GROUP BY 
    region_name, nation_name, customer_name
ORDER BY 
    total_revenue DESC;
