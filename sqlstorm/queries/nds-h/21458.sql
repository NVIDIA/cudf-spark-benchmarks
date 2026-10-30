WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FlaggedLineItems AS (
    SELECT 
        l.*, 
        CASE 
            WHEN l.l_discount > 0.2 THEN 'High Discount'
            WHEN l.l_discount BETWEEN 0.1 AND 0.2 THEN 'Medium Discount'
            ELSE 'No Discount'
        END AS discount_flag
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag IS NULL 
        AND l.l_shipdate < cast('1998-10-01' as date) 
),
JoinOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        l.l_linenumber, 
        l.l_quantity * (1 - l.l_discount) AS discounted_price
    FROM 
        orders o
    INNER JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
),
AggregateStats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        FlaggedLineItems l ON l.l_suppkey = n.n_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    ss.total_cost AS supplier_cost,
    ls.o_orderkey,
    ls.discounted_price,
    ag.nation_count,
    ag.total_extended_price,
    CASE 
        WHEN ag.total_extended_price IS NULL THEN 'No Sales'
        WHEN ag.total_extended_price > 100000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierStats ss ON rp.p_partkey = ss.s_suppkey
FULL OUTER JOIN 
    JoinOrders ls ON rp.p_partkey = ls.l_linenumber
CROSS JOIN 
    AggregateStats ag
WHERE 
    (ss.total_cost IS NOT NULL OR ag.nation_count > 0)
    AND (rp.rn = 1 OR rp.p_name LIKE '%special%')
ORDER BY 
    rp.p_retailprice DESC, 
    ss.total_cost ASC NULLS LAST;