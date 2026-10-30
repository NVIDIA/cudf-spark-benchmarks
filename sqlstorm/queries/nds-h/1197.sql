WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderstatus IN ('O', 'F') 
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) as customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 1000
),
OrderLineSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(h.c_name, 'Unknown') AS customer_name,
    COALESCE(h.c_acctbal, 0) AS customer_account_balance,
    sd.s_name AS supplier_name,
    sd.total_supplycost,
    ols.total_revenue,
    ols.line_count
FROM 
    RankedOrders r
LEFT JOIN 
    HighValueCustomers h ON r.o_orderkey = h.c_custkey
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
JOIN 
    OrderLineSummary ols ON r.o_orderkey = ols.l_orderkey
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_orderdate DESC, 
    r.o_orderkey;