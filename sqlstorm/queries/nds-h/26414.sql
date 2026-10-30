WITH PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        SUBSTR(p.p_comment, 1, 10) AS short_comment
    FROM part p
    WHERE p.p_retailprice > 0
),
SupplierNation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        n.n_name AS nation_name,
        CASE 
            WHEN s.s_acctbal > 10000 THEN 'High Balance'
            WHEN s.s_acctbal BETWEEN 5000 AND 10000 THEN 'Medium Balance'
            ELSE 'Low Balance'
        END AS balance_category
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    pi.p_partkey,
    pi.p_name,
    pi.p_brand,
    pi.p_type,
    sn.nation_name,
    sn.balance_category,
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent,
    pi.comment_length,
    pi.short_comment
FROM PartInfo pi
JOIN SupplierNation sn ON pi.p_container = SUBSTR(sn.s_name, 1, 2)
JOIN CustomerOrders co ON pi.p_partkey = co.order_count
WHERE pi.comment_length > 20
ORDER BY pi.p_retailprice DESC, co.total_spent DESC;
