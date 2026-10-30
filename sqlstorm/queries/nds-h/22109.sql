WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_price
    FROM 
        part p
), 
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        MIN(s.s_acctbal) AS min_supplier_balance
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spending,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND 
        c.c_mktsegment IN ('AUTOMOBILE', 'FURNITURE')
    GROUP BY 
        c.c_custkey
), 
RegionalStats AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returns
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    sv.total_avail_qty,
    sv.min_supplier_balance,
    co.order_count,
    co.total_spending,
    rs.total_sales,
    rs.total_returns
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierAvailability sv ON rp.p_partkey = sv.ps_partkey
LEFT JOIN 
    CustomerOrders co ON co.total_spending > 1000 AND co.order_count > 2
LEFT JOIN 
    RegionalStats rs ON TRUE 
WHERE 
    rp.rank_price <= 5
AND 
    (sv.total_avail_qty IS NOT NULL OR sv.min_supplier_balance IS NOT NULL)
ORDER BY 
    rp.p_retailprice DESC, 
    co.last_order_date DESC
LIMIT 10;
