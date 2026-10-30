WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
BestSupplier AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM 
        SupplierStats ss
    WHERE 
        ss.part_count > 5
)
SELECT 
    bd.o_orderkey,
    bd.o_orderdate,
    bd.total_revenue,
    COALESCE(bs.s_name, 'Unknown Supplier') AS supplier_name,
    bd.total_quantity,
    (SELECT AVG(l_discount) FROM lineitem WHERE l_orderkey = bd.o_orderkey) AS avg_discount
FROM 
    OrderDetails bd
LEFT JOIN 
    BestSupplier bs ON bd.o_orderkey % 10 = bs.s_suppkey % 10
WHERE 
    (bd.total_revenue > 1000 OR bd.total_quantity > 50) 
    AND (bd.o_orderdate >= '1997-01-01' OR bd.o_orderdate IS NULL)
ORDER BY 
    bd.total_revenue DESC NULLS LAST
LIMIT 50;