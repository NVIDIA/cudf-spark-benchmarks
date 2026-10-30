WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand, p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_size > 20)
),
SupplierNation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        n.n_comment AS nation_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS num_line_items,
        o.o_orderdate,
        o.o_orderpriority
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_orderpriority
),
FinalBenchmark AS (
    SELECT 
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        sn.nation_name,
        os.total_revenue,
        os.num_line_items,
        os.o_orderpriority
    FROM 
        RankedParts rp
    JOIN 
        SupplierNation sn ON rp.rank = 1
    JOIN 
        OrderSummary os ON os.num_line_items > 5
    WHERE 
        rp.p_comment LIKE '%quality%'
)
SELECT 
    p_name, 
    p_brand, 
    p_type, 
    nation_name, 
    total_revenue, 
    num_line_items, 
    o_orderpriority 
FROM 
    FinalBenchmark
ORDER BY 
    total_revenue DESC
LIMIT 10;