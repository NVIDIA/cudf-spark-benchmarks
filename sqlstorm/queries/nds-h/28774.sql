WITH RankedParts AS (
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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS total_parts
    FROM part p
    WHERE p.p_size BETWEEN 20 AND 30
),
BestSellers AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_quantity) AS total_sold
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
    HAVING SUM(l.l_quantity) > 100
),
CustomerSegmentation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal >= 10000 THEN 'High Value'
            WHEN c.c_acctbal BETWEEN 5000 AND 9999 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customer c
),
OrderAnalysis AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        EXTRACT(MONTH FROM o.o_orderdate) AS order_month,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus, order_month
)
SELECT 
    rp.p_name,
    rp.rank_price,
    rp.total_parts,
    bs.total_sold,
    cs.customer_segment,
    oa.total_revenue,
    oa.order_month
FROM RankedParts rp
LEFT JOIN BestSellers bs ON rp.p_partkey = bs.ps_partkey
JOIN CustomerSegmentation cs ON cs.customer_segment = 
    CASE 
        WHEN bs.total_sold IS NULL THEN 'Low Value'
        WHEN bs.total_sold > 1000 THEN 'High Value'
        ELSE 'Medium Value'
    END
JOIN OrderAnalysis oa ON oa.o_orderkey = (SELECT MIN(o.o_orderkey) 
                                            FROM orders o 
                                            WHERE o.o_orderstatus = 'O' 
                                            AND o.o_orderkey > 0)
WHERE rp.rank_price <= 5 AND rp.total_parts > 1;
