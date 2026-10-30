
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_lineitem_revenue,
        COUNT(li.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_supply_value,
        s.part_count,
        ROW_NUMBER() OVER (ORDER BY s.total_supply_value DESC) AS rank
    FROM 
        SupplierStats s
    WHERE 
        s.part_count > 5
)
SELECT 
    ts.s_name,
    ts.total_supply_value,
    od.total_lineitem_revenue,
    od.total_line_items
FROM 
    TopSuppliers ts
LEFT JOIN 
    OrderDetails od ON ts.s_suppkey = (
        SELECT 
            ps.ps_suppkey
        FROM 
            partsupp ps
        JOIN 
            part p ON ps.ps_partkey = p.p_partkey
        WHERE 
            p.p_size > 10
        ORDER BY 
            ps.ps_supplycost DESC
        LIMIT 1
    )
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.total_supply_value DESC, od.total_lineitem_revenue DESC;
