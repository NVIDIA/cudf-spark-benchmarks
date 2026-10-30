WITH  part_supplier_stats AS (
    SELECT 
        ps.ps_partkey,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY AVG(ps.ps_supplycost) DESC) AS rn
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
),
region_nation_summary AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_open_orders,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        STRING_AGG(DISTINCT o.o_orderpriority, ', ') AS priorities,
        MAX(c.c_acctbal) AS max_account_balance
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    COALESCE(s.joined_suppliers, 'No Suppliers') AS supplier_info,
    rs.nation_count,
    cs.total_open_orders,
    cs.max_account_balance
FROM 
    part p
LEFT JOIN (
    SELECT 
        ps_partkey,
        STRING_AGG(DISTINCT s_name, ', ') AS joined_suppliers
    FROM 
        part_supplier_stats pss
    JOIN 
        supplier s ON pss.ps_partkey = s.s_suppkey
    GROUP BY 
        ps_partkey
) s ON p.p_partkey = s.ps_partkey
LEFT JOIN region_nation_summary rs ON rs.total_supplier_balance > (SELECT AVG(s_acctbal) FROM supplier)
LEFT JOIN customer_order_summary cs ON cs.order_count = (SELECT MAX(order_count) FROM customer_order_summary)
WHERE 
    p.p_size BETWEEN 1 AND 50
    AND EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey AND ps.ps_availqty > 0)
ORDER BY 
    p.p_partkey;
