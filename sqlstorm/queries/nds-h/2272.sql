WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),

SuppliersWithCost AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2) 
        AND c.c_mktsegment IN ('BUILDING', 'FURNITURE')
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(s.s_name, 'UNKNOWN SUPPLIER') AS supplier_name,
    COALESCE(h.c_name, 'UNKNOWN CUSTOMER') AS customer_name,
    r.total_revenue,
    s.total_supply_cost,
    CASE 
        WHEN r.total_revenue IS NULL THEN 'NO REVENUE'
        ELSE 'REVENUE GENERATED'
    END AS revenue_status
FROM 
    RankedOrders r
LEFT JOIN 
    SuppliersWithCost s ON r.o_orderkey = s.s_suppkey  
LEFT JOIN 
    HighValueCustomers h ON r.o_orderkey = h.c_custkey  
WHERE 
    r.revenue_rank <= 10
ORDER BY 
    r.total_revenue DESC, 
    r.o_orderdate ASC;