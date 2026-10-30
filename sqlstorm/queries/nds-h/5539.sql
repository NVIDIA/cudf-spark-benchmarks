WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopCustomers AS (
    SELECT 
        o_orderkey,
        o_orderdate,
        c_name
    FROM 
        RankedOrders
    WHERE 
        revenue_rank <= 10
)
SELECT 
    tc.o_orderkey,
    tc.o_orderdate,
    tc.c_name,
    COUNT(DISTINCT l.l_orderkey) AS lineitem_count,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_extended_price
FROM 
    TopCustomers tc
JOIN 
    lineitem l ON tc.o_orderkey = l.l_orderkey
GROUP BY 
    tc.o_orderkey, tc.o_orderdate, tc.c_name
ORDER BY 
    tc.o_orderdate, total_quantity DESC;
