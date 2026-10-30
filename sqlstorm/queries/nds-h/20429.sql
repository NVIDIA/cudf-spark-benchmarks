WITH  ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderstatus IN ('O', 'F')
), 
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        STRING_AGG(DISTINCT p.p_type, ', ') AS part_types
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
), 
customer_details AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 0.00
            ELSE c.c_acctbal
        END AS modified_acctbal,
        COALESCE(n.n_name, 'Unknown') AS nation_name
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    coalesce(rn.o_orderkey, 0) AS order_key,
    csr.c_custkey,
    csr.c_name,
    ss.s_suppkey,
    ss.s_name,
    ss.total_parts,
    ss.part_types,
    SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS adjusted_total
FROM ranked_orders rn
FULL OUTER JOIN customer_details csr ON rn.o_orderkey = csr.c_custkey
JOIN lineitem l ON rn.o_orderkey = l.l_orderkey
JOIN supplier_summary ss ON l.l_suppkey = ss.s_suppkey
WHERE (rn.rank <= 10 OR ss.total_cost > 10000)
GROUP BY 
    coalesce(rn.o_orderkey, 0),
    csr.c_custkey,
    csr.c_name,
    ss.s_suppkey,
    ss.s_name,
    ss.total_parts,
    ss.part_types
HAVING 
    SUM(l.l_quantity) FILTER (WHERE l.l_returnflag = 'R') > 0
    OR MIN(rn.o_orderdate) < '1997-03-01'
ORDER BY adjusted_total DESC, csr.c_name
LIMIT 50;