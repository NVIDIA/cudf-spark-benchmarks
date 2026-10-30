
WITH EnhancedPartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        LENGTH(p.p_comment) AS comment_length,
        CASE 
            WHEN POSITION('special' IN p.p_comment) > 0 THEN 'contains_special' 
            ELSE 'regular' 
        END AS comment_category
    FROM part p
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(s.s_suppkey) AS total_suppliers,
        AVG(s.s_acctbal) AS avg_acct_balance,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names 
    FROM supplier s
    GROUP BY s.s_nationkey
),
AggregatedInfo AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice) AS total_revenue,
        MAX(p.p_retailprice) AS max_part_price,
        MIN(p.p_retailprice) AS min_part_price,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
        AVG(sd.comment_length * CAST(p.p_retailprice AS decimal)) AS adjusted_length
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN EnhancedPartDetails sd ON p.p_partkey = sd.p_partkey
    WHERE sd.comment_category = 'contains_special'
    GROUP BY n.n_name
)
SELECT 
    ai.n_name AS nation_name,
    ai.total_orders,
    ai.total_revenue,
    ai.max_part_price,
    ai.min_part_price,
    ai.supplier_names,
    ROUND(ai.adjusted_length, 2) AS avg_adjusted_length
FROM AggregatedInfo ai
ORDER BY ai.total_revenue DESC
LIMIT 10;
