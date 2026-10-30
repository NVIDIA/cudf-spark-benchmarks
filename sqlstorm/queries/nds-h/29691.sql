WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_type LIKE '%metal%'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
),
TopCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS revenue_rank
    FROM 
        CustomerSummary cs
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT sp.s_suppkey) AS supplier_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sales,
    COUNT(DISTINCT rc.c_custkey) AS loyal_customers,
    SUM(CASE WHEN tp.rank <= 5 THEN 1 ELSE 0 END) AS top_part_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier sp ON n.n_nationkey = sp.s_nationkey
JOIN 
    partsupp ps ON sp.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    TopCustomers rc ON rc.c_custkey = l.l_orderkey
JOIN 
    RankedParts tp ON tp.p_partkey = p.p_partkey
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    region_name, nation_name;
