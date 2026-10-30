
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_comment,
        n.n_name AS nation_name,
        SUBSTRING(s.s_comment, 1, 30) AS short_comment,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier AS s
    JOIN 
        nation AS n ON s.s_nationkey = n.n_nationkey
),
PartsAggregated AS (
    SELECT 
        ps.ps_partkey,
        COUNT(ps.ps_suppkey) AS total_suppliers,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp AS ps
    GROUP BY 
        ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(*) AS total_line_items,
        MAX(l.l_extendedprice) AS max_extended_price
    FROM 
        orders AS o
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    pd.s_suppkey AS supp_key,
    pd.s_name,
    pd.nation_name,
    pa.total_suppliers,
    pa.total_available_qty,
    od.total_quantity,
    od.total_line_items,
    od.max_extended_price
FROM 
    SupplierDetails AS pd
JOIN 
    PartsAggregated AS pa ON pd.s_suppkey = pa.ps_partkey
JOIN 
    OrderDetails AS od ON pa.ps_partkey = od.o_orderkey
WHERE 
    od.total_quantity > 100 AND
    pd.comment_length > 50
ORDER BY 
    pd.nation_name, 
    pa.total_available_qty DESC;
