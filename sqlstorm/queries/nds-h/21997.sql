
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),

FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        p.p_comment,
        CASE 
            WHEN p.p_size BETWEEN 1 AND 50 THEN 'Small'
            WHEN p.p_size BETWEEN 51 AND 100 THEN 'Medium'
            ELSE 'Large'
        END AS size_category,
        COALESCE(NULLIF(p.p_comment, ''), 'No Comment') AS normalized_comment
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),

FinalOutput AS (
    SELECT 
        f.p_partkey,
        f.p_name,
        r.r_name AS region_name,
        su.s_name AS supplier_name,
        SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_quantity ELSE 0 END) AS total_returns,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        FilteredParts f
    LEFT JOIN 
        partsupp ps ON f.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier su ON ps.ps_suppkey = su.s_suppkey
    LEFT JOIN 
        RankedOrders o ON su.s_nationkey = o.o_custkey
    LEFT JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    LEFT JOIN 
        region r ON su.s_nationkey = r.r_regionkey
    WHERE 
        r.r_name IS NOT NULL 
        AND f.size_category = 'Large'
    GROUP BY 
        f.p_partkey, f.p_name, r.r_name, su.s_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > (SELECT AVG(order_count) FROM (SELECT COUNT(DISTINCT o.o_orderkey) AS order_count FROM orders o GROUP BY o.o_custkey) AS avg_orders)
)

SELECT 
    *,
    CASE 
        WHEN total_returns > 50 THEN 'High'
        ELSE 'Low'
    END AS return_rate_category
FROM 
    FinalOutput
ORDER BY 
    total_returns DESC, region_name;
