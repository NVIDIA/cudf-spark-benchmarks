
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey = s.s_nationkey
        )
    GROUP BY 
        s.s_suppkey, s.s_name
),

OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_orderkey) AS item_count,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1994-01-01' AND '1995-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)

SELECT 
    si.s_name,
    si.part_count,
    si.total_availqty,
    si.total_supplycost,
    os.total_price,
    os.item_count,
    CASE 
        WHEN os.price_rank = 1 THEN 'TOP'
        WHEN os.price_rank <= 5 THEN 'HIGH'
        ELSE 'LOW'
    END AS price_category
FROM 
    SupplierInfo si
FULL OUTER JOIN 
    OrderSummary os ON si.part_count = os.item_count
WHERE 
    (si.total_supplycost IS NULL OR si.total_supplycost > 1000)
    AND (os.total_price IS NOT NULL AND os.total_price < 5000)
ORDER BY 
    si.part_count DESC, 
    os.total_price ASC NULLS LAST;
