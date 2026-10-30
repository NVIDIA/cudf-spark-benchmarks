WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
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
)
SELECT 
    cs.c_name,
    cs.total_spent,
    cs.order_count,
    sd.s_name,
    sd.total_supply_cost
FROM 
    CustomerSummary cs
LEFT JOIN 
    SupplierDetails sd ON cs.order_count > 5 AND sd.total_supply_cost IS NOT NULL
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
    OR (sd.total_supply_cost IS NULL AND EXISTS (SELECT 1 FROM Part p WHERE p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > 100)))
ORDER BY 
    cs.total_spent DESC, sd.total_supply_cost ASC
LIMIT 10;