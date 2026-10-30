
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank_supplier 
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 10
),
TotalRevenue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
HighRevenueOrders AS (
    SELECT 
        tr.o_orderkey,
        tr.total_revenue,
        ROW_NUMBER() OVER (ORDER BY tr.total_revenue DESC) AS order_rank 
    FROM 
        TotalRevenue tr
    WHERE 
        tr.total_revenue > 100000
)
SELECT 
    rs.s_name,
    COUNT(*) AS num_orders_with_supplies,
    AVG(rs.s_acctbal) AS avg_supplier_balance
FROM 
    RankedSuppliers rs
JOIN 
    HighRevenueOrders hro ON hro.o_orderkey = rs.s_suppkey
WHERE 
    rs.rank_supplier = 1
GROUP BY 
    rs.s_name
HAVING 
    COUNT(*) > 5
ORDER BY 
    avg_supplier_balance DESC;
