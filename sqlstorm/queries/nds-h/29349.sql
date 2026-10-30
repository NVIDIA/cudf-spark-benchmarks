WITH supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, s.s_acctbal, s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
    FROM part p
    WHERE LENGTH(p.p_name) > 10 AND p.p_retailprice > 100.00
),
line_item_details AS (
    SELECT l.l_orderkey, COUNT(DISTINCT l.l_partkey) AS part_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    GROUP BY l.l_orderkey
),
final_output AS (
    SELECT sd.s_name, sd.nation_name, pd.p_name, pd.p_brand, pd.p_retailprice, lid.part_count, lid.total_price
    FROM supplier_details sd
    JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    JOIN part_details pd ON ps.ps_partkey = pd.p_partkey
    JOIN line_item_details lid ON lid.l_orderkey = ps.ps_partkey
    WHERE sd.s_acctbal > 5000.00
)
SELECT *
FROM final_output
ORDER BY total_price DESC, s_name ASC;
