
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < DATE '1998-10-01' AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    LEFT JOIN 
        partsupp p ON s.s_suppkey = p.ps_suppkey
    WHERE 
        p.ps_availqty > 0
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSupplierDetails AS (
    SELECT 
        ro.o_orderkey,
        fl.total_line_value,
        si.s_name,
        si.avg_account_balance
    FROM 
        RankedOrders ro
    LEFT JOIN 
        FilteredLineItems fl ON ro.o_orderkey = fl.l_orderkey
    LEFT JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    LEFT JOIN 
        SupplierInfo si ON l.l_suppkey = si.s_suppkey
    WHERE 
        fl.total_line_value IS NOT NULL AND ro.order_rank <= 5
)
SELECT 
    osd.o_orderkey,
    COALESCE(osd.total_line_value, 0) AS order_total_value,
    osd.s_name,
    CASE 
        WHEN osd.avg_account_balance IS NULL THEN 'No Suppliers'
        ELSE CAST(osd.avg_account_balance AS STRING)
    END AS average_supplier_balance
FROM 
    OrderSupplierDetails osd
WHERE 
    osd.o_orderkey IS NOT NULL
ORDER BY 
    order_total_value DESC, osd.o_orderkey
LIMIT 10;
