WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01' 
        AND o.o_orderstatus IN ('O', 'F', 'P')
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 10
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        n.n_comment,
        COALESCE(s.s_acctbal, 0) AS supplier_balance
    FROM 
        nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey 
    WHERE 
        n.n_comment IS NOT NULL AND LENGTH(n.n_comment) > 25
),
MaxRevenue AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
),
FinalResult AS (
    SELECT 
        po.p_partkey,
        po.p_name,
        CONCAT('Supplier: ', fn.n_name, ' - Revenue: ', COALESCE(mr.revenue, 0)) AS detail_info
    FROM 
        part po
    LEFT JOIN FilteredNations fn ON po.p_mfgr = fn.n_name 
    LEFT JOIN MaxRevenue mr ON mr.l_orderkey IN (SELECT o.o_orderkey FROM RankedOrders o WHERE o.rn <= 10)
    WHERE 
        po.p_size BETWEEN 10 AND 20
        AND po.p_retailprice IS NOT NULL
)
SELECT DISTINCT
    fr.detail_info,
    COUNT(DISTINCT sp.ps_suppkey) AS active_suppliers
FROM 
    FinalResult fr
LEFT JOIN SupplierParts sp ON fr.p_partkey = sp.ps_partkey
GROUP BY 
    fr.detail_info
HAVING 
    COUNT(DISTINCT sp.ps_suppkey) > 1
ORDER BY 
    active_suppliers DESC, fr.detail_info;
