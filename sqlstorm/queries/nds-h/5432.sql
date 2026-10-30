WITH OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
        COUNT(l.l_orderkey) AS total_items,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_name, 
        os.total_revenue,
        os.o_orderdate,
        RANK() OVER (PARTITION BY os.o_orderdate ORDER BY os.total_revenue DESC) AS rank
    FROM 
        OrderSummary os
    JOIN 
        customer c ON os.o_orderkey = c.c_custkey
)
SELECT 
    tc.o_orderdate, 
    tc.c_name, 
    tc.total_revenue
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.o_orderdate, tc.total_revenue DESC;