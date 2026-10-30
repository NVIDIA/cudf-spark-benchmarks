WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01'
),
CustomerSummary AS (
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
),
SupplierInventory AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
)
SELECT 
    cs.c_name,
    cs.total_spent,
    cs.order_count,
    si.s_name AS supplier_name,
    si.total_available_qty,
    si.avg_supply_cost
FROM 
    CustomerSummary cs
LEFT JOIN 
    SupplierInventory si ON cs.order_count > 5 AND si.total_available_qty IS NOT NULL
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
ORDER BY 
    cs.total_spent DESC
LIMIT 10;