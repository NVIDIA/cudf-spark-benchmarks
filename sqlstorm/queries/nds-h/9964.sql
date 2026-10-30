
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_orderkey) AS order_line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
FinalSummary AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.nation_name,
        ss.total_supply_value,
        ss.unique_parts,
        os.total_order_value,
        os.order_line_count
    FROM 
        SupplierSummary ss
    LEFT JOIN 
        OrderSummary os ON ss.s_suppkey = (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey IN (
                SELECT p.p_partkey 
                FROM part p 
                WHERE p.p_size > 30
            )
            LIMIT 1
        )
)
SELECT 
    f.nation_name,
    COUNT(DISTINCT f.s_suppkey) AS supplier_count,
    SUM(f.total_supply_value) AS total_supply_value,
    AVG(f.total_order_value) AS average_order_value
FROM 
    FinalSummary f
GROUP BY 
    f.nation_name
ORDER BY 
    supplier_count DESC, total_supply_value DESC;
