WITH nation_summary AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
),
part_retail_summary AS (
    SELECT 
        p.p_brand,
        SUM(p.p_retailprice) AS total_retail_price,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_brand
),
order_aggregates AS (
    SELECT 
        o.o_orderstatus,
        SUM(l.l_extendedprice) AS total_order_value,
        COUNT(DISTINCT o.o_custkey) AS total_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderstatus
)
SELECT 
    ns.nation_name,
    ns.customer_count,
    ns.total_supplier_balance,
    ps.total_retail_price,
    ps.unique_suppliers,
    oa.o_orderstatus,
    oa.total_order_value,
    oa.total_customers
FROM 
    nation_summary ns
LEFT JOIN 
    part_retail_summary ps ON ps.p_brand IN (SELECT DISTINCT p_brand FROM part) 
LEFT JOIN 
    order_aggregates oa ON oa.o_orderstatus = 'O' 
ORDER BY 
    ns.customer_count DESC, 
    ps.total_retail_price DESC, 
    oa.total_order_value DESC
LIMIT 100;