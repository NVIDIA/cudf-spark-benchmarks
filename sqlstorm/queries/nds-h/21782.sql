
WITH RankedNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS ranked_suppliers
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, n.n_regionkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(CASE 
                WHEN ps.ps_supplycost IS NULL THEN 0 
                ELSE ps.ps_supplycost * ps.ps_availqty 
            END) AS total_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
CustomerOrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
)
SELECT 
    fn.n_name AS nation_name,
    fp.p_name AS part_name,
    COALESCE(ecd.total_value, 0) AS total_order_value,
    fp.total_cost AS part_total_cost,
    CASE 
        WHEN ecd.total_value > fp.total_cost THEN 'Profitable'
        WHEN ecd.total_value = fp.total_cost THEN 'Break-even'
        ELSE 'Loss'
    END AS profitability,
    COUNT(DISTINCT so.o_orderkey) AS total_orders,
    MAX(ecd.o_orderdate) AS last_order_date
FROM 
    RankedNations fn
LEFT JOIN 
    FilteredParts fp ON fn.ranked_suppliers = 1
LEFT JOIN 
    CustomerOrderDetails ecd ON ecd.rank = 1
LEFT JOIN 
    orders so ON ecd.o_orderkey = so.o_orderkey
WHERE 
    fn.n_nationkey IS NOT NULL
GROUP BY 
    fn.n_name, fp.p_name, fp.total_cost, ecd.total_value
HAVING 
    COUNT(ecd.total_value) = 0
ORDER BY 
    CASE 
        WHEN profitability = 'Profitable' THEN 1 
        WHEN profitability = 'Loss' THEN 2 
        ELSE 3 
    END, 
    total_orders DESC;
