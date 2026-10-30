WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
), 
part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS nation_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    p.p_name,
    p.p_retailprice,
    COALESCE(s.s_name, 'UNKNOWN SUPPLIER') AS supplier_name,
    COALESCE(s.nation_name, 'UNKNOWN NATION') AS nation_name,
    CASE 
        WHEN p.total_available IS NULL THEN 0 
        ELSE p.total_available 
    END AS available_quantity,
    p.avg_supply_cost,
    COUNT(l.l_orderkey) AS line_item_count
FROM 
    ranked_orders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    part_supplier p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    supplier_info s ON l.l_suppkey = s.s_suppkey AND s.nation_rank = 1
WHERE 
    r.rank = 1 
    AND r.o_totalprice > (SELECT AVG(o_totalprice) FROM ranked_orders WHERE rank = 1)
GROUP BY 
    r.o_orderkey, r.o_totalprice, p.p_name, p.p_retailprice,
    s.s_name, s.nation_name, p.total_available, p.avg_supply_cost
ORDER BY 
    r.o_orderkey, p.p_name;