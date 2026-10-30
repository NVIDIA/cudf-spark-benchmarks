
WITH TotalSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSales AS (
    SELECT 
        ts.c_custkey,
        ts.c_name,
        ts.total_revenue,
        RANK() OVER (ORDER BY ts.total_revenue DESC) AS revenue_rank
    FROM 
        TotalSales ts
),
TopCustomers AS (
    SELECT 
        * 
    FROM 
        RankedSales 
    WHERE 
        revenue_rank <= 10
)
SELECT 
    tc.c_name,
    tc.total_revenue,
    c.c_address,
    s.s_name AS supplier_name,
    s.s_acctbal,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM 
    TopCustomers tc
JOIN 
    orders o ON tc.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON tc.c_custkey = c.c_custkey
GROUP BY 
    tc.c_name, 
    tc.total_revenue, 
    c.c_address, 
    s.s_name, 
    s.s_acctbal
ORDER BY 
    tc.total_revenue DESC;
