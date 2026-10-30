
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_avail_qty,
        ss.total_supply_cost,
        DENSE_RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supply_rank
    FROM 
        SupplierStats ss
),
OrderPerformance AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_item_count,
        MIN(l.l_shipdate) AS first_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.s_name,
    ts.total_avail_qty,
    ts.total_supply_cost,
    op.total_revenue,
    op.line_item_count,
    op.first_ship_date
FROM 
    TopSuppliers ts
LEFT JOIN 
    OrderPerformance op ON ts.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_size > 10 
            AND p.p_retailprice BETWEEN 50.00 AND 100.00
        )
        GROUP BY ps.ps_suppkey
        ORDER BY SUM(ps.ps_availqty) DESC 
        LIMIT 1
    )
WHERE 
    ts.supply_rank <= 5
ORDER BY 
    ts.total_supply_cost DESC, op.total_revenue DESC;
