
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name
    FROM 
        SupplierStats s
    WHERE 
        s.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
)
SELECT 
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(ss.total_supply_cost, 0) AS supplier_cost,
    CASE 
        WHEN c.total_spent >= 10000 THEN 'VIP'
        ELSE 'Regular'
    END AS customer_status
FROM 
    CustomerOrderSummary c
LEFT JOIN 
    lineitem l ON c.c_custkey = l.l_orderkey
LEFT JOIN 
    SupplierStats ss ON l.l_suppkey = ss.s_suppkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND l.l_returnflag = 'N'
    AND c.rank <= 10
GROUP BY 
    c.c_name, ss.total_supply_cost, c.total_spent
ORDER BY 
    total_revenue DESC;
