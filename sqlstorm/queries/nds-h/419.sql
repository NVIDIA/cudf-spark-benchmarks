WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
), CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierPartStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    rs.o_orderkey,
    cs.c_name,
    cs.total_spent,
    sp.part_count,
    sp.total_supply_cost,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent > 1000 THEN 'VIP Customer'
        ELSE 'Regular Customer'
    END AS customer_status,
    COALESCE(sp.part_count, 0) AS available_parts
FROM 
    RankedOrders rs
JOIN 
    CustomerSummary cs ON rs.o_orderkey = cs.c_custkey
LEFT JOIN 
    SupplierPartStats sp ON cs.c_custkey = sp.s_suppkey
WHERE 
    rs.order_rank = 1
ORDER BY 
    rs.o_orderdate DESC
LIMIT 100;