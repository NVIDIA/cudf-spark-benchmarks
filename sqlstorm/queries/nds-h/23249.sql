
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER(PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), 
CombinedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN si.total_supply_cost > 500000 THEN 'High Value Supplier'
            WHEN si.total_supply_cost BETWEEN 200000 AND 500000 THEN 'Medium Value Supplier'
            ELSE 'Low Value Supplier'
        END AS supplier_value
    FROM 
        SupplierInfo si 
    INNER JOIN 
        supplier s ON s.s_suppkey = si.s_suppkey
), 
FinalResults AS (
    SELECT 
        r.r_name,
        rp.p_name,
        os.total_price,
        cs.supplier_value,
        CASE 
            WHEN rp.rank <= 5 THEN 'Top 5 by Price'
            ELSE 'Not in Top 5'
        END AS retail_rank
    FROM 
        region r
    JOIN nation n ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON c.c_nationkey = n.n_nationkey
    JOIN orders o ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN RankedParts rp ON l.l_partkey = rp.p_partkey
    JOIN CombinedSuppliers cs ON cs.s_suppkey = l.l_suppkey
    JOIN OrderSummary os ON os.o_orderkey = o.o_orderkey
    WHERE 
        (os.unique_parts > 1 OR os.total_price IS NOT NULL)
        AND rp.p_retailprice IS NOT NULL
)
SELECT 
    r_name,
    p_name,
    MAX(total_price) AS max_price,
    COUNT(DISTINCT supplier_value) AS supplier_categories
FROM 
    FinalResults
GROUP BY 
    r_name, p_name
HAVING 
    COUNT(DISTINCT supplier_value) > 1
ORDER BY 
    r_name, max_price DESC;
