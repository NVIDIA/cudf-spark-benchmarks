WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS CustomerRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
),
TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ro.o_orderkey) AS total_orders,
        SUM(ro.o_totalprice) AS total_spent
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.CustomerRank <= 5
    GROUP BY 
        r.r_name, n.n_name
),
SupplierParts AS (
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
AggregatedData AS (
    SELECT 
        tc.region_name,
        tc.nation_name,
        tc.total_orders,
        tc.total_spent,
        sp.s_name,
        sp.total_supply_cost
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SupplierParts sp ON tc.region_name IS NOT NULL
)
SELECT 
    ad.region_name,
    ad.nation_name,
    ad.total_orders,
    COALESCE(ad.total_spent, 0) AS total_spent,
    ad.s_name AS supplier_name,
    COALESCE(ad.total_supply_cost, 0) AS supplier_total_cost,
    CONCAT('Region: ', ad.region_name, ', Nation: ', ad.nation_name, ' - Total Orders: ', ad.total_orders) AS summary_info
FROM 
    AggregatedData ad
WHERE 
    ad.total_orders > 10
ORDER BY 
    ad.total_spent DESC, ad.region_name;
