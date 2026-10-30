WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighVolumeCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    RO.o_orderkey,
    RO.o_orderdate,
    RO.o_totalprice,
    S.s_name AS supplier_name,
    H.c_name AS customer_name,
    COALESCE(S.total_supply_cost, 0) AS supplier_cost,
    H.total_spent AS customer_spend,
    CASE 
        WHEN H.total_spent IS NOT NULL THEN 'High Value'
        ELSE 'Standard'
    END AS customer_segment
FROM 
    RankedOrders RO
LEFT JOIN 
    lineitem L ON RO.o_orderkey = L.l_orderkey
LEFT JOIN 
    partsupp PS ON L.l_partkey = PS.ps_partkey
LEFT JOIN 
    SupplierDetails S ON PS.ps_suppkey = S.s_suppkey
LEFT JOIN 
    HighVolumeCustomers H ON RO.o_orderkey = H.c_custkey
WHERE 
    (RO.order_rank <= 10 OR H.total_spent IS NOT NULL)
ORDER BY 
    RO.o_orderdate DESC, RO.o_totalprice ASC;