WITH TopSuppliers AS (
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
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), 
OrdersWithSupplier AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        l.l_partkey, 
        l.l_quantity, 
        ts.total_supply_cost
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
        AND l.l_quantity > 0
)
SELECT 
    ows.o_orderkey,
    COUNT(ows.l_partkey) AS total_parts,
    SUM(ows.l_quantity) AS total_quantity,
    AVG(ows.total_supply_cost) AS avg_supply_cost
FROM 
    OrdersWithSupplier ows
GROUP BY 
    ows.o_orderkey
HAVING 
    SUM(ows.l_quantity) > 100
ORDER BY 
    avg_supply_cost DESC
LIMIT 10;