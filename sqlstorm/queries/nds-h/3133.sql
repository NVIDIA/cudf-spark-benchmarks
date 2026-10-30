
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_supply_value DESC) AS rank
    FROM 
        SupplierStats
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.part_count,
    t.total_supply_value,
    o.o_orderkey,
    o.total_price,
    'Top Supplier' AS supplier_status
FROM 
    TopSuppliers t
LEFT JOIN 
    OrderSummary o ON t.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey IN (
                SELECT o.o_orderkey 
                FROM orders o 
                WHERE o.o_orderstatus = 'O'
            )
        )
    )
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_supply_value DESC, 
    o.total_price DESC NULLS LAST;
