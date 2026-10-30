
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighCostSuppliers AS (
    SELECT 
        * 
    FROM 
        RankedSuppliers 
    WHERE 
        rank_in_nation <= 3
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        l.l_partkey, 
        l.l_quantity,
        l.l_extendedprice,
        hcs.s_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        HighCostSuppliers hcs ON l.l_suppkey = hcs.s_suppkey
)
SELECT 
    od.o_orderkey, 
    od.o_orderdate, 
    COUNT(DISTINCT od.l_partkey) AS unique_parts_count,
    SUM(od.l_extendedprice * od.l_quantity) AS total_order_value,
    AVG(od.l_quantity) AS avg_quantity_per_part,
    MAX(od.l_extendedprice) AS max_price_per_part
FROM 
    OrderDetails od
GROUP BY 
    od.o_orderkey, od.o_orderdate
ORDER BY 
    total_order_value DESC
LIMIT 10;
