WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_nationkey,
        COUNT(DISTINCT ps_partkey) AS part_count,
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_nationkey
),
CustomerOrdering AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.part_count,
        sd.total_supply_cost,
        n.n_name
    FROM 
        SupplierDetails sd
    JOIN 
        nation n ON sd.s_nationkey = n.n_nationkey
    WHERE 
        sd.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierDetails)
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.total_order_value,
    ho.part_count,
    ho.total_supply_cost,
    ho.n_name,
    (SELECT COUNT(DISTINCT l.l_orderkey) 
     FROM lineitem l 
     WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
     AND l.l_discount BETWEEN 0.05 AND 0.10) AS total_discounted_lines,
    CASE 
        WHEN ho.total_supply_cost IS NULL THEN 'Unknown'
        ELSE ho.n_name
    END AS supplier_nation
FROM 
    CustomerOrdering co
JOIN 
    HighValueSuppliers ho ON co.total_order_value > 10000
WHERE 
    co.last_order_date = (SELECT MAX(last_order_date) FROM CustomerOrdering)
    AND NOT EXISTS (
        SELECT 1 
        FROM orders o 
        WHERE o.o_custkey = co.c_custkey 
        AND o.o_orderstatus NOT IN ('O', 'F')
    )
ORDER BY 
    co.total_order_value DESC
LIMIT 10;