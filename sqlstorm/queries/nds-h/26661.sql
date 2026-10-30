WITH supplier_info AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length,
        REGEXP_REPLACE(s.s_comment, '[^A-Za-z0-9]', '') AS cleaned_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
part_info AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        LENGTH(p.p_comment) AS comment_length,
        REGEXP_REPLACE(p.p_comment, '[^A-Za-z0-9]', '') AS cleaned_comment
    FROM part p
),
order_summary AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_orderdate
)
SELECT
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    ps.ps_availqty AS available_quantity,
    os.total_sales,
    os.line_count,
    s.comment_length AS supplier_comment_length,
    p.comment_length AS part_comment_length,
    CASE
        WHEN os.total_sales > 1000 THEN 'High Value'
        WHEN os.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM supplier_info s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part_info p ON ps.ps_partkey = p.p_partkey
JOIN order_summary os ON os.o_orderkey = ps.ps_partkey
WHERE LENGTH(s.cleaned_comment) > 10
AND LENGTH(p.cleaned_comment) > 10
ORDER BY os.total_sales DESC, supplier_name, part_name;
