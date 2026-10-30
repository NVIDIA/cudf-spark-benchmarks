WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_size, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) as size_ranking
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_size > 0)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 50000
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        COUNT(l.l_orderkey) AS lineitem_count, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
FinalBenchmark AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        sd.s_name AS supplier_name,
        co.total_sales,
        co.lineitem_count
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    JOIN 
        CustomerOrders co ON co.o_custkey = sd.s_nationkey
    WHERE 
        rp.size_ranking <= 5
    ORDER BY 
        rp.p_retailprice DESC, co.total_sales DESC
)
SELECT * FROM FinalBenchmark;
